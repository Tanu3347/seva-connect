import { Router } from 'express';
import {
  getVolunteerProfile,
  updateVolunteerProfile,
} from '../controllers/profile.controller';
import { authenticate, authorize } from '../middlewares/auth.middleware';

const router = Router();

router.get(
  '/me',
  authenticate,
  authorize(['VOLUNTEER']),
  getVolunteerProfile,
);
router.patch(
  '/me',
  authenticate,
  authorize(['VOLUNTEER']),
  updateVolunteerProfile,
);

export default router;
