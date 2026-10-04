import { Router } from 'express';
import {
  createOpportunity,
  getOpportunities,
  getMyOpportunities,
  getOpportunityById,
  updateOpportunity,
  deleteOpportunity,
} from '../controllers/opportunity.controller';
import {
  applyToOpportunity,
  getApplicationsForOpportunity,
} from '../controllers/application.controller';
import { authenticate, authorize } from '../middlewares/auth.middleware';

const router = Router();

// Public / volunteer browse & search opportunities
router.get('/', getOpportunities);

// NGO view own opportunities
router.get('/my', authenticate, authorize(['NGO']), getMyOpportunities);

// View single opportunity details
router.get('/:id', getOpportunityById);

// NGO create opportunity
router.post('/', authenticate, authorize(['NGO']), createOpportunity);

// NGO update opportunity (ownership enforced)
router.put('/:id', authenticate, authorize(['NGO']), updateOpportunity);

// NGO delete opportunity (ownership enforced)
router.delete('/:id', authenticate, authorize(['NGO']), deleteOpportunity);

// Volunteer apply to opportunity
router.post('/:opportunityId/apply', authenticate, authorize(['VOLUNTEER']), applyToOpportunity);

// NGO view applications for specific opportunity
router.get('/:opportunityId/applications', authenticate, authorize(['NGO']), getApplicationsForOpportunity);

export default router;
