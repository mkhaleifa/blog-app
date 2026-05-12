import { Request, Response } from 'express'
import jwt from 'jsonwebtoken'
import { validationResult } from 'express-validator'
import User from '../models/User'
import { AuthRequest } from '../middleware/auth'

const signToken = (id: string): string => {
  const secret = process.env.JWT_SECRET || 'fallback_secret'
  const expiresIn = process.env.JWT_EXPIRES_IN || '7d'
  return jwt.sign({ id }, secret, { expiresIn } as jwt.SignOptions)
}

export const register = async (req: Request, res: Response): Promise<void> => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) { res.status(400).json({ success: false, errors: errors.array() }); return }
  try {
    const { name, email, password } = req.body
    const existingUser = await User.findOne({ email })
    if (existingUser) { res.status(400).json({ success: false, message: 'Email already registered' }); return }
    const user = await User.create({ name, email, password })
    const token = signToken(user._id.toString())
    res.status(201).json({ success: true, token, user: { id: user._id, name: user.name, email: user.email } })
  } catch {
    res.status(500).json({ success: false, message: 'Server error during registration' })
  }
}

export const login = async (req: Request, res: Response): Promise<void> => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) { res.status(400).json({ success: false, errors: errors.array() }); return }
  try {
    const { email, password } = req.body
    const user = await User.findOne({ email }).select('+password')
    if (!user || !(await user.comparePassword(password))) {
      res.status(401).json({ success: false, message: 'Invalid email or password' }); return
    }
    const token = signToken(user._id.toString())
    res.json({ success: true, token, user: { id: user._id, name: user.name, email: user.email } })
  } catch {
    res.status(500).json({ success: false, message: 'Server error during login' })
  }
}

export const getMe = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = await User.findById(req.user?._id)
    res.json({ success: true, user })
  } catch {
    res.status(500).json({ success: false, message: 'Server error' })
  }
}
