import { Router } from 'express'
import { body } from 'express-validator'
import { register, login, getMe } from '../controllers/authController'
import { protect } from '../middleware/auth'

const router = Router()

router.post('/register', [
  body('name').trim().notEmpty().withMessage('Name is required').isLength({ max: 50 }),
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
], register)

router.post('/login', [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
], login)

router.get('/me', protect, getMe)

export default router
