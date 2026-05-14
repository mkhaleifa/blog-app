import express from 'express'
import cors from 'cors'
import morgan from 'morgan'
import dotenv from 'dotenv'
import connectDB from './config/db'
import authRoutes from './routes/auth'
import postRoutes from './routes/posts'

dotenv.config()

const app = express()

connectDB()

app.use(
  cors({
    origin: process.env.CLIENT_URL || 'http://localhost:5173',
    credentials: true,
  })
)

app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true }))
app.use(morgan('dev'))

app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  })
})

app.use('/api/auth', authRoutes)
app.use('/api/posts', postRoutes)

app.use((_req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  })
})

app.use(
  (
    err: Error,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction
  ) => {
    console.error(err.stack)

    res.status(500).json({
      success: false,
      message: err.message || 'Internal server error',
    })
  }
)

export default app