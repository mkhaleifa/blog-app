#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Blog App — Full Setup Script         ${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ─────────────────────────────────────────
# BACKEND SETUP
# ─────────────────────────────────────────
echo -e "${YELLOW}[1/6] Creating backend folder structure...${NC}"
mkdir -p backend/src/{controllers,routes,models,middleware,config}

echo -e "${YELLOW}[2/6] Writing backend files...${NC}"

# ── package.json ──
cat > backend/package.json << 'EOF'
{
  "name": "blog-backend",
  "version": "1.0.0",
  "main": "dist/server.js",
  "scripts": {
    "dev": "nodemon --exec ts-node src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "express-validator": "^7.2.0",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^8.5.1",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/jsonwebtoken": "^9.0.6",
    "@types/morgan": "^1.9.9",
    "@types/node": "^22.0.0",
    "nodemon": "^3.1.4",
    "ts-node": "^10.9.2",
    "typescript": "^5.5.4"
  }
}
EOF

# ── tsconfig.json ──
cat > backend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# ── .env.example ──
cat > backend/.env.example << 'EOF'
PORT=5000
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/blog-app?retryWrites=true&w=majority
JWT_SECRET=change_this_to_any_long_random_string
JWT_EXPIRES_IN=7d
NODE_ENV=development
EOF

# ── .gitignore ──
cat > backend/.gitignore << 'EOF'
node_modules/
dist/
.env
*.log
EOF

# ── config/db.ts ──
cat > backend/src/config/db.ts << 'EOF'
import mongoose from 'mongoose'

const connectDB = async (): Promise<void> => {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/blog-app'
    await mongoose.connect(mongoUri)
    console.log('✅ MongoDB connected successfully')
  } catch (error) {
    console.error('❌ MongoDB connection error:', error)
    process.exit(1)
  }
}

export default connectDB
EOF

# ── models/User.ts ──
cat > backend/src/models/User.ts << 'EOF'
import mongoose, { Document, Schema } from 'mongoose'
import bcrypt from 'bcryptjs'

export interface IUser extends Document {
  _id: mongoose.Types.ObjectId
  name: string
  email: string
  password: string
  avatar?: string
  bio?: string
  createdAt: Date
  comparePassword(candidatePassword: string): Promise<boolean>
}

const userSchema = new Schema<IUser>(
  {
    name: { type: String, required: [true, 'Name is required'], trim: true, maxlength: 50 },
    email: { type: String, required: [true, 'Email is required'], unique: true, lowercase: true, trim: true },
    password: { type: String, required: [true, 'Password is required'], minlength: 6, select: false },
    avatar: { type: String, default: '' },
    bio: { type: String, maxlength: 200 },
  },
  { timestamps: true }
)

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next()
  this.password = await bcrypt.hash(this.password, 12)
  next()
})

userSchema.methods.comparePassword = async function (candidatePassword: string): Promise<boolean> {
  return bcrypt.compare(candidatePassword, this.password)
}

export default mongoose.model<IUser>('User', userSchema)
EOF

# ── models/Post.ts ──
cat > backend/src/models/Post.ts << 'EOF'
import mongoose, { Document, Schema } from 'mongoose'

export interface IPost extends Document {
  _id: mongoose.Types.ObjectId
  title: string
  slug: string
  content: string
  excerpt: string
  coverImage?: string
  author: mongoose.Types.ObjectId
  tags: string[]
  status: 'draft' | 'published'
  views: number
  likes: mongoose.Types.ObjectId[]
  createdAt: Date
  updatedAt: Date
}

const postSchema = new Schema<IPost>(
  {
    title: { type: String, required: true, trim: true, maxlength: 150 },
    slug: { type: String, unique: true, lowercase: true },
    content: { type: String, required: true },
    excerpt: { type: String, maxlength: 300 },
    coverImage: { type: String, default: '' },
    author: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    tags: [{ type: String, lowercase: true, trim: true }],
    status: { type: String, enum: ['draft', 'published'], default: 'draft' },
    views: { type: Number, default: 0 },
    likes: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
)

postSchema.pre('save', function (next) {
  if (this.isModified('title')) {
    this.slug = this.title.toLowerCase().replace(/[^a-z0-9 ]/g, '').replace(/\s+/g, '-').slice(0, 80) + '-' + Date.now()
  }
  if (this.isModified('content') && !this.excerpt) {
    this.excerpt = this.content.replace(/<[^>]*>/g, '').slice(0, 200) + '...'
  }
  next()
})

postSchema.index({ title: 'text', content: 'text', tags: 'text' })
postSchema.index({ slug: 1 })
postSchema.index({ author: 1, status: 1 })

export default mongoose.model<IPost>('Post', postSchema)
EOF

# ── middleware/auth.ts ──
cat > backend/src/middleware/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'
import User, { IUser } from '../models/User'

export interface AuthRequest extends Request {
  user?: IUser
}

interface JwtPayload { id: string }

export const protect = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const authHeader = req.headers.authorization
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ success: false, message: 'Not authorized — no token' })
      return
    }
    const token = authHeader.split(' ')[1]
    const secret = process.env.JWT_SECRET || 'fallback_secret'
    const decoded = jwt.verify(token, secret) as JwtPayload
    const user = await User.findById(decoded.id)
    if (!user) {
      res.status(401).json({ success: false, message: 'User no longer exists' })
      return
    }
    req.user = user
    next()
  } catch {
    res.status(401).json({ success: false, message: 'Invalid or expired token' })
  }
}
EOF

# ── controllers/authController.ts ──
cat > backend/src/controllers/authController.ts << 'EOF'
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
EOF

# ── controllers/postController.ts ──
cat > backend/src/controllers/postController.ts << 'EOF'
import { Response } from 'express'
import { validationResult } from 'express-validator'
import Post from '../models/Post'
import { AuthRequest } from '../middleware/auth'

export const getPosts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const page = parseInt(req.query.page as string) || 1
    const limit = parseInt(req.query.limit as string) || 10
    const skip = (page - 1) * limit
    const tag = req.query.tag as string
    const search = req.query.search as string
    const query: Record<string, unknown> = { status: 'published' }
    if (tag) query.tags = tag
    if (search) query.$text = { $search: search }
    const [posts, total] = await Promise.all([
      Post.find(query).populate('author', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(limit).select('-content'),
      Post.countDocuments(query),
    ])
    res.json({ success: true, data: posts, pagination: { page, limit, total, pages: Math.ceil(total / limit) } })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}

export const getPost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findOne({ slug: req.params.slug, status: 'published' }).populate('author', 'name avatar bio')
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    post.views += 1
    await post.save()
    res.json({ success: true, data: post })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}

export const createPost = async (req: AuthRequest, res: Response): Promise<void> => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) { res.status(400).json({ success: false, errors: errors.array() }); return }
  try {
    const { title, content, excerpt, coverImage, tags, status } = req.body
    const post = await Post.create({ title, content, excerpt, coverImage, tags: tags || [], status: status || 'draft', author: req.user?._id })
    res.status(201).json({ success: true, data: post })
  } catch { res.status(500).json({ success: false, message: 'Server error creating post' }) }
}

export const updatePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findById(req.params.id)
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    if (post.author.toString() !== req.user?._id.toString()) {
      res.status(403).json({ success: false, message: 'Not authorized to edit this post' }); return
    }
    const { title, content, excerpt, coverImage, tags, status } = req.body
    if (title) post.title = title
    if (content) post.content = content
    if (excerpt) post.excerpt = excerpt
    if (coverImage !== undefined) post.coverImage = coverImage
    if (tags) post.tags = tags
    if (status) post.status = status
    await post.save()
    res.json({ success: true, data: post })
  } catch { res.status(500).json({ success: false, message: 'Server error updating post' }) }
}

export const deletePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findById(req.params.id)
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    if (post.author.toString() !== req.user?._id.toString()) {
      res.status(403).json({ success: false, message: 'Not authorized to delete this post' }); return
    }
    await post.deleteOne()
    res.json({ success: true, message: 'Post deleted successfully' })
  } catch { res.status(500).json({ success: false, message: 'Server error deleting post' }) }
}

export const getMyPosts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const posts = await Post.find({ author: req.user?._id }).sort({ createdAt: -1 })
    res.json({ success: true, data: posts })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}

export const likePost = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const post = await Post.findById(req.params.id)
    if (!post) { res.status(404).json({ success: false, message: 'Post not found' }); return }
    const userId = req.user?._id
    const alreadyLiked = post.likes.some(id => id.toString() === userId?.toString())
    if (alreadyLiked) {
      post.likes = post.likes.filter(id => id.toString() !== userId?.toString())
    } else {
      post.likes.push(userId!)
    }
    await post.save()
    res.json({ success: true, likes: post.likes.length, liked: !alreadyLiked })
  } catch { res.status(500).json({ success: false, message: 'Server error' }) }
}
EOF

# ── routes/auth.ts ──
cat > backend/src/routes/auth.ts << 'EOF'
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
EOF

# ── routes/posts.ts ──
cat > backend/src/routes/posts.ts << 'EOF'
import { Router } from 'express'
import { body } from 'express-validator'
import { getPosts, getPost, createPost, updatePost, deletePost, getMyPosts, likePost } from '../controllers/postController'
import { protect } from '../middleware/auth'

const router = Router()

const postValidation = [
  body('title').trim().notEmpty().withMessage('Title is required').isLength({ max: 150 }),
  body('content').notEmpty().withMessage('Content is required'),
]

router.get('/', getPosts)
router.get('/my', protect, getMyPosts)
router.get('/:slug', getPost)
router.post('/', protect, postValidation, createPost)
router.put('/:id', protect, updatePost)
router.delete('/:id', protect, deletePost)
router.post('/:id/like', protect, likePost)

export default router
EOF

# ── server.ts ──
cat > backend/src/server.ts << 'EOF'
import express from 'express'
import cors from 'cors'
import morgan from 'morgan'
import dotenv from 'dotenv'
import connectDB from './config/db'
import authRoutes from './routes/auth'
import postRoutes from './routes/posts'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 5000

connectDB()

app.use(cors({ origin: process.env.NODE_ENV === 'production' ? process.env.CLIENT_URL : 'http://localhost:5173', credentials: true }))
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true }))
app.use(morgan('dev'))

app.get('/api/health', (_req, res) => { res.json({ status: 'ok', timestamp: new Date().toISOString() }) })
app.use('/api/auth', authRoutes)
app.use('/api/posts', postRoutes)

app.use((_req, res) => { res.status(404).json({ success: false, message: 'Route not found' }) })
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err.stack)
  res.status(500).json({ success: false, message: err.message || 'Internal server error' })
})

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`)
})

export default app
EOF

# ─────────────────────────────────────────
# FRONTEND SETUP
# ─────────────────────────────────────────
echo -e "${YELLOW}[3/6] Creating frontend folder structure...${NC}"
mkdir -p frontend/src/{pages,components/layout,hooks,api,store,types}
mkdir -p frontend/public

# ── package.json ──
cat > frontend/package.json << 'EOF'
{
  "name": "blog-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@hookform/resolvers": "^3.9.0",
    "@tanstack/react-query": "^5.51.1",
    "axios": "^1.7.2",
    "date-fns": "^3.6.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-hook-form": "^7.52.1",
    "react-hot-toast": "^2.4.1",
    "react-router-dom": "^6.25.1",
    "zod": "^3.23.8",
    "zustand": "^4.5.4"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.40",
    "tailwindcss": "^3.4.7",
    "typescript": "^5.5.3",
    "vite": "^5.3.4"
  }
}
EOF

# ── vite.config.ts ──
cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:5000',
        changeOrigin: true,
      },
    },
  },
})
EOF

# ── tsconfig.json ──
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

# ── tsconfig.node.json ──
cat > frontend/tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF

# ── tailwind.config.js ──
cat > frontend/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: { extend: {} },
  plugins: [],
}
EOF

# ── postcss.config.js ──
cat > frontend/postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# ── index.html ──
cat > frontend/index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>BlogApp</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# ── .gitignore ──
cat > frontend/.gitignore << 'EOF'
node_modules/
dist/
.env
*.log
EOF

echo -e "${YELLOW}[4/6] Writing frontend source files...${NC}"

# ── src/index.css ──
cat > frontend/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body { @apply text-gray-900 antialiased; }
}

.prose p { @apply mb-4; }
.prose h1 { @apply text-2xl font-semibold mb-4 mt-6; }
.prose h2 { @apply text-xl font-semibold mb-3 mt-6; }
.prose h3 { @apply text-lg font-semibold mb-2 mt-4; }
.prose ul { @apply list-disc pl-6 mb-4; }
.prose ol { @apply list-decimal pl-6 mb-4; }
.prose li { @apply mb-1; }
.prose code { @apply bg-gray-100 px-1.5 py-0.5 rounded text-sm font-mono; }
.prose pre { @apply bg-gray-900 text-gray-100 p-4 rounded-xl mb-4 overflow-x-auto; }
.prose blockquote { @apply border-l-4 border-gray-200 pl-4 italic text-gray-500 mb-4; }
EOF

# ── src/main.tsx ──
cat > frontend/src/main.tsx << 'EOF'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
EOF

# ── src/App.tsx ──
cat > frontend/src/App.tsx << 'EOF'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'react-hot-toast'
import Navbar from './components/layout/Navbar'
import ProtectedRoute from './components/ProtectedRoute'
import HomePage from './pages/HomePage'
import PostPage from './pages/PostPage'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import PostFormPage from './pages/PostFormPage'
import DashboardPage from './pages/DashboardPage'

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, staleTime: 1000 * 60 } },
})

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <div className="min-h-screen bg-white">
          <Navbar />
          <main>
            <Routes>
              <Route path="/" element={<HomePage />} />
              <Route path="/posts/:slug" element={<PostPage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />
              <Route path="/new" element={<ProtectedRoute><PostFormPage /></ProtectedRoute>} />
              <Route path="/edit/:id" element={<ProtectedRoute><PostFormPage /></ProtectedRoute>} />
              <Route path="/dashboard" element={<ProtectedRoute><DashboardPage /></ProtectedRoute>} />
            </Routes>
          </main>
        </div>
        <Toaster position="bottom-right" />
      </BrowserRouter>
    </QueryClientProvider>
  )
}

export default App
EOF

# ── src/types/index.ts ──
cat > frontend/src/types/index.ts << 'EOF'
export interface User {
  id: string
  name: string
  email: string
  avatar?: string
  bio?: string
}

export interface Post {
  _id: string
  title: string
  slug: string
  content: string
  excerpt: string
  coverImage?: string
  author: Pick<User, 'id' | 'name' | 'avatar'> & { _id: string }
  tags: string[]
  status: 'draft' | 'published'
  views: number
  likes: string[]
  createdAt: string
  updatedAt: string
}

export interface PaginatedResponse<T> {
  success: boolean
  data: T[]
  pagination: { page: number; limit: number; total: number; pages: number }
}

export interface ApiResponse<T> {
  success: boolean
  data?: T
  message?: string
  token?: string
  user?: User
}

export interface LoginForm { email: string; password: string }
export interface RegisterForm { name: string; email: string; password: string }
export interface PostForm {
  title: string
  content: string
  excerpt?: string
  coverImage?: string
  tags?: string
  status: 'draft' | 'published'
}
EOF

# ── src/api/client.ts ──
cat > frontend/src/api/client.ts << 'EOF'
import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
EOF

# ── src/api/index.ts ──
cat > frontend/src/api/index.ts << 'EOF'
import api from './client'
import type { LoginForm, RegisterForm, PostForm, ApiResponse, User, Post, PaginatedResponse } from '../types'

export const authApi = {
  register: (data: RegisterForm) => api.post<ApiResponse<User>>('/auth/register', data),
  login: (data: LoginForm) => api.post<ApiResponse<User>>('/auth/login', data),
  getMe: () => api.get<ApiResponse<User>>('/auth/me'),
}

export const postsApi = {
  getAll: (params?: { page?: number; limit?: number; tag?: string; search?: string }) =>
    api.get<PaginatedResponse<Post>>('/posts', { params }),
  getBySlug: (slug: string) => api.get<ApiResponse<Post>>(`/posts/${slug}`),
  getMyPosts: () => api.get<ApiResponse<Post[]>>('/posts/my'),
  create: (data: PostForm) => api.post<ApiResponse<Post>>('/posts', {
    ...data,
    tags: data.tags ? data.tags.split(',').map(t => t.trim()) : [],
  }),
  update: (id: string, data: Partial<PostForm>) => api.put<ApiResponse<Post>>(`/posts/${id}`, {
    ...data,
    tags: data.tags ? data.tags.split(',').map(t => t.trim()) : undefined,
  }),
  delete: (id: string) => api.delete<ApiResponse<null>>(`/posts/${id}`),
  like: (id: string) => api.post<{ success: boolean; likes: number; liked: boolean }>(`/posts/${id}/like`),
}
EOF

# ── src/store/authStore.ts ──
cat > frontend/src/store/authStore.ts << 'EOF'
import { create } from 'zustand'
import type { User } from '../types'

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  setAuth: (user: User, token: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: localStorage.getItem('token'),
  isAuthenticated: !!localStorage.getItem('token'),
  setAuth: (user, token) => {
    localStorage.setItem('token', token)
    set({ user, token, isAuthenticated: true })
  },
  logout: () => {
    localStorage.removeItem('token')
    set({ user: null, token: null, isAuthenticated: false })
  },
}))
EOF

# ── src/components/ProtectedRoute.tsx ──
cat > frontend/src/components/ProtectedRoute.tsx << 'EOF'
import { Navigate } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuthStore()
  if (!isAuthenticated) return <Navigate to="/login" replace />
  return <>{children}</>
}
EOF

# ── src/components/layout/Navbar.tsx ──
cat > frontend/src/components/layout/Navbar.tsx << 'EOF'
import { Link, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'

export default function Navbar() {
  const { isAuthenticated, user, logout } = useAuthStore()
  const navigate = useNavigate()

  const handleLogout = () => { logout(); navigate('/') }

  return (
    <nav className="border-b border-gray-200 bg-white sticky top-0 z-50">
      <div className="max-w-4xl mx-auto px-4 py-3 flex items-center justify-between">
        <Link to="/" className="text-xl font-semibold text-gray-900">📝 BlogApp</Link>
        <div className="flex items-center gap-4">
          <Link to="/" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Home</Link>
          {isAuthenticated ? (
            <>
              <Link to="/new" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">New Post</Link>
              <Link to="/dashboard" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Dashboard</Link>
              <span className="text-sm text-gray-500">Hi, {user?.name?.split(' ')[0]}</span>
              <button onClick={handleLogout} className="text-sm bg-gray-100 hover:bg-gray-200 text-gray-700 px-3 py-1.5 rounded-lg transition-colors">Logout</button>
            </>
          ) : (
            <>
              <Link to="/login" className="text-sm text-gray-600 hover:text-gray-900 transition-colors">Login</Link>
              <Link to="/register" className="text-sm bg-gray-900 hover:bg-gray-700 text-white px-3 py-1.5 rounded-lg transition-colors">Sign Up</Link>
            </>
          )}
        </div>
      </div>
    </nav>
  )
}
EOF

# ── src/pages/HomePage.tsx ──
cat > frontend/src/pages/HomePage.tsx << 'EOF'
import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { format } from 'date-fns'
import { postsApi } from '../api'

export default function HomePage() {
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')

  const { data, isLoading, isError } = useQuery({
    queryKey: ['posts', page, search],
    queryFn: () => postsApi.getAll({ page, limit: 9, search: search || undefined }),
  })

  const posts = data?.data.data || []
  const pagination = data?.data.pagination

  return (
    <div className="max-w-4xl mx-auto px-4 py-10">
      <div className="mb-10">
        <h1 className="text-3xl font-semibold text-gray-900 mb-2">Latest Posts</h1>
        <p className="text-gray-500">Thoughts, ideas and articles</p>
      </div>
      <div className="mb-8">
        <input type="text" placeholder="Search posts..." value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1) }}
          className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
      </div>
      {isLoading && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => <div key={i} className="animate-pulse bg-gray-100 rounded-xl h-52" />)}
        </div>
      )}
      {isError && <div className="text-center py-20 text-red-500">Failed to load posts. Make sure the backend is running.</div>}
      {!isLoading && !isError && (
        <>
          {posts.length === 0 ? (
            <div className="text-center py-20 text-gray-400">No posts found.</div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-10">
              {posts.map((post) => (
                <Link key={post._id} to={`/posts/${post.slug}`}
                  className="group border border-gray-200 rounded-xl p-5 hover:border-gray-400 transition-all hover:shadow-sm">
                  {post.coverImage && <img src={post.coverImage} alt={post.title} className="w-full h-36 object-cover rounded-lg mb-4" />}
                  <div className="flex flex-wrap gap-1 mb-2">
                    {post.tags.slice(0, 2).map(tag => (
                      <span key={tag} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">{tag}</span>
                    ))}
                  </div>
                  <h2 className="font-semibold text-gray-900 mb-2 group-hover:text-gray-600 transition-colors line-clamp-2">{post.title}</h2>
                  <p className="text-sm text-gray-500 line-clamp-2 mb-4">{post.excerpt}</p>
                  <div className="flex items-center justify-between text-xs text-gray-400">
                    <span>{post.author.name}</span>
                    <span>{format(new Date(post.createdAt), 'MMM d, yyyy')}</span>
                  </div>
                </Link>
              ))}
            </div>
          )}
          {pagination && pagination.pages > 1 && (
            <div className="flex items-center justify-center gap-2">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}
                className="px-4 py-2 text-sm border border-gray-200 rounded-lg disabled:opacity-40 hover:bg-gray-50 transition-colors">Previous</button>
              <span className="text-sm text-gray-500">Page {page} of {pagination.pages}</span>
              <button onClick={() => setPage(p => Math.min(pagination.pages, p + 1))} disabled={page === pagination.pages}
                className="px-4 py-2 text-sm border border-gray-200 rounded-lg disabled:opacity-40 hover:bg-gray-50 transition-colors">Next</button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
EOF

# ── src/pages/PostPage.tsx ──
cat > frontend/src/pages/PostPage.tsx << 'EOF'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { format } from 'date-fns'
import { postsApi } from '../api'
import { useAuthStore } from '../store/authStore'
import toast from 'react-hot-toast'

export default function PostPage() {
  const { slug } = useParams<{ slug: string }>()
  const { isAuthenticated, user } = useAuthStore()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data, isLoading, isError } = useQuery({
    queryKey: ['post', slug],
    queryFn: () => postsApi.getBySlug(slug!),
    enabled: !!slug,
  })

  const post = data?.data.data

  const likeMutation = useMutation({
    mutationFn: () => postsApi.like(post!._id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['post', slug] }),
  })

  const deleteMutation = useMutation({
    mutationFn: () => postsApi.delete(post!._id),
    onSuccess: () => { toast.success('Post deleted'); navigate('/dashboard') },
    onError: () => toast.error('Failed to delete post'),
  })

  if (isLoading) return (
    <div className="max-w-3xl mx-auto px-4 py-10 animate-pulse">
      <div className="h-8 bg-gray-100 rounded w-3/4 mb-4" />
      <div className="h-4 bg-gray-100 rounded w-1/4 mb-10" />
      <div className="space-y-3">{[...Array(8)].map((_, i) => <div key={i} className="h-4 bg-gray-100 rounded" />)}</div>
    </div>
  )

  if (isError || !post) return <div className="max-w-3xl mx-auto px-4 py-20 text-center text-red-500">Post not found.</div>

  const isAuthor = user?.id === post.author._id || user?.id === (post.author as unknown as { _id: string })._id
  const isLiked = post.likes.includes(user?.id || '')

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <div className="flex flex-wrap gap-2 mb-4">
        {post.tags.map(tag => <span key={tag} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">{tag}</span>)}
      </div>
      <h1 className="text-3xl font-semibold text-gray-900 mb-4">{post.title}</h1>
      <div className="flex items-center gap-4 text-sm text-gray-400 mb-8 pb-6 border-b border-gray-100">
        <span>{post.author.name}</span><span>·</span>
        <span>{format(new Date(post.createdAt), 'MMMM d, yyyy')}</span><span>·</span>
        <span>{post.views} views</span>
      </div>
      {post.coverImage && <img src={post.coverImage} alt={post.title} className="w-full rounded-xl mb-8 object-cover max-h-96" />}
      <div className="prose prose-gray max-w-none text-gray-700 leading-relaxed"
        dangerouslySetInnerHTML={{ __html: post.content.replace(/\n/g, '<br/>') }} />
      <div className="flex items-center gap-3 mt-10 pt-6 border-t border-gray-100">
        {isAuthenticated && (
          <button onClick={() => likeMutation.mutate()}
            className={`flex items-center gap-1.5 px-4 py-2 text-sm rounded-lg border transition-colors ${isLiked ? 'bg-red-50 border-red-200 text-red-500' : 'border-gray-200 text-gray-600 hover:bg-gray-50'}`}>
            {isLiked ? '❤️' : '🤍'} {post.likes.length}
          </button>
        )}
        {isAuthor && (
          <>
            <button onClick={() => navigate(`/edit/${post._id}`)}
              className="px-4 py-2 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">Edit</button>
            <button onClick={() => { if (confirm('Delete this post?')) deleteMutation.mutate() }}
              className="px-4 py-2 text-sm border border-red-200 text-red-500 rounded-lg hover:bg-red-50 transition-colors">Delete</button>
          </>
        )}
      </div>
    </div>
  )
}
EOF

# ── src/pages/LoginPage.tsx ──
cat > frontend/src/pages/LoginPage.tsx << 'EOF'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { authApi } from '../api'
import { useAuthStore } from '../store/authStore'

const loginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})
type LoginForm = z.infer<typeof loginSchema>

export default function LoginPage() {
  const navigate = useNavigate()
  const { setAuth } = useAuthStore()
  const { register, handleSubmit, formState: { errors } } = useForm<LoginForm>({ resolver: zodResolver(loginSchema) })

  const mutation = useMutation({
    mutationFn: authApi.login,
    onSuccess: (res) => {
      const { token, user } = res.data
      if (token && user) { setAuth(user, token); toast.success(`Welcome back, ${user.name}!`); navigate('/') }
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
      toast.error(msg || 'Login failed')
    },
  })

  return (
    <div className="min-h-[80vh] flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <h1 className="text-2xl font-semibold text-gray-900 mb-1">Welcome back</h1>
        <p className="text-gray-500 text-sm mb-8">Sign in to your account</p>
        <form onSubmit={handleSubmit((data) => mutation.mutate(data))} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input {...register('email')} type="email" placeholder="you@example.com"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
            {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input {...register('password')} type="password" placeholder="••••••••"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
            {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
          </div>
          <button type="submit" disabled={mutation.isPending}
            className="w-full bg-gray-900 hover:bg-gray-700 text-white py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50">
            {mutation.isPending ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
        <p className="text-center text-sm text-gray-500 mt-6">
          Don't have an account? <Link to="/register" className="text-gray-900 font-medium hover:underline">Sign up</Link>
        </p>
      </div>
    </div>
  )
}
EOF

# ── src/pages/RegisterPage.tsx ──
cat > frontend/src/pages/RegisterPage.tsx << 'EOF'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { authApi } from '../api'
import { useAuthStore } from '../store/authStore'

const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(50),
  email: z.string().email('Invalid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})
type RegisterForm = z.infer<typeof registerSchema>

export default function RegisterPage() {
  const navigate = useNavigate()
  const { setAuth } = useAuthStore()
  const { register, handleSubmit, formState: { errors } } = useForm<RegisterForm>({ resolver: zodResolver(registerSchema) })

  const mutation = useMutation({
    mutationFn: authApi.register,
    onSuccess: (res) => {
      const { token, user } = res.data
      if (token && user) { setAuth(user, token); toast.success('Account created!'); navigate('/') }
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
      toast.error(msg || 'Registration failed')
    },
  })

  return (
    <div className="min-h-[80vh] flex items-center justify-center px-4">
      <div className="w-full max-w-sm">
        <h1 className="text-2xl font-semibold text-gray-900 mb-1">Create account</h1>
        <p className="text-gray-500 text-sm mb-8">Start writing today</p>
        <form onSubmit={handleSubmit((data) => mutation.mutate(data))} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
            <input {...register('name')} placeholder="Mohamed Khaleifa"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
            {errors.name && <p className="text-red-500 text-xs mt-1">{errors.name.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input {...register('email')} type="email" placeholder="you@example.com"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
            {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input {...register('password')} type="password" placeholder="••••••••"
              className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
            {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
          </div>
          <button type="submit" disabled={mutation.isPending}
            className="w-full bg-gray-900 hover:bg-gray-700 text-white py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50">
            {mutation.isPending ? 'Creating account...' : 'Create account'}
          </button>
        </form>
        <p className="text-center text-sm text-gray-500 mt-6">
          Already have an account? <Link to="/login" className="text-gray-900 font-medium hover:underline">Sign in</Link>
        </p>
      </div>
    </div>
  )
}
EOF

# ── src/pages/PostFormPage.tsx ──
cat > frontend/src/pages/PostFormPage.tsx << 'EOF'
import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { useNavigate, useParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import toast from 'react-hot-toast'
import { postsApi } from '../api'
import type { PostForm } from '../types'

export default function PostFormPage() {
  const { id } = useParams<{ id: string }>()
  const isEditing = !!id
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const { data: existingPost } = useQuery({
    queryKey: ['post-edit', id],
    queryFn: () => postsApi.getMyPosts(),
    enabled: isEditing,
    select: (res) => res.data.data?.find(p => p._id === id),
  })

  const { register, handleSubmit, reset, formState: { errors } } = useForm<PostForm>({ defaultValues: { status: 'draft' } })

  useEffect(() => {
    if (existingPost) {
      reset({ title: existingPost.title, content: existingPost.content, excerpt: existingPost.excerpt,
        coverImage: existingPost.coverImage, tags: existingPost.tags.join(', '), status: existingPost.status })
    }
  }, [existingPost, reset])

  const createMutation = useMutation({
    mutationFn: postsApi.create,
    onSuccess: (res) => { queryClient.invalidateQueries({ queryKey: ['posts'] }); toast.success('Post created!'); navigate(`/posts/${res.data.data?.slug}`) },
    onError: () => toast.error('Failed to create post'),
  })

  const updateMutation = useMutation({
    mutationFn: (data: Partial<PostForm>) => postsApi.update(id!, data),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['posts'] }); toast.success('Post updated!'); navigate('/dashboard') },
    onError: () => toast.error('Failed to update post'),
  })

  const onSubmit = (data: PostForm) => { if (isEditing) updateMutation.mutate(data); else createMutation.mutate(data) }
  const isPending = createMutation.isPending || updateMutation.isPending

  return (
    <div className="max-w-2xl mx-auto px-4 py-10">
      <h1 className="text-2xl font-semibold text-gray-900 mb-8">{isEditing ? 'Edit Post' : 'New Post'}</h1>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Title *</label>
          <input {...register('title', { required: 'Title is required' })} placeholder="Your post title..."
            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
          {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title.message}</p>}
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Cover Image URL</label>
          <input {...register('coverImage')} placeholder="https://example.com/image.jpg"
            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Tags (comma separated)</label>
          <input {...register('tags')} placeholder="react, javascript, web-dev"
            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Excerpt</label>
          <textarea {...register('excerpt')} rows={2} placeholder="A short description of your post..."
            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300 resize-none" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Content *</label>
          <textarea {...register('content', { required: 'Content is required' })} rows={14} placeholder="Write your post content here..."
            className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300 resize-y font-mono" />
          {errors.content && <p className="text-red-500 text-xs mt-1">{errors.content.message}</p>}
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
          <select {...register('status')} className="border border-gray-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-gray-300">
            <option value="draft">Draft</option>
            <option value="published">Published</option>
          </select>
        </div>
        <div className="flex gap-3 pt-2">
          <button type="submit" disabled={isPending}
            className="bg-gray-900 hover:bg-gray-700 text-white px-6 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50">
            {isPending ? 'Saving...' : isEditing ? 'Update Post' : 'Publish'}
          </button>
          <button type="button" onClick={() => navigate(-1)}
            className="border border-gray-200 px-6 py-2.5 rounded-xl text-sm text-gray-600 hover:bg-gray-50 transition-colors">Cancel</button>
        </div>
      </form>
    </div>
  )
}
EOF

# ── src/pages/DashboardPage.tsx ──
cat > frontend/src/pages/DashboardPage.tsx << 'EOF'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { format } from 'date-fns'
import { postsApi } from '../api'
import { useAuthStore } from '../store/authStore'
import toast from 'react-hot-toast'

export default function DashboardPage() {
  const { user } = useAuthStore()
  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery({ queryKey: ['my-posts'], queryFn: postsApi.getMyPosts })
  const posts = data?.data.data || []
  const published = posts.filter(p => p.status === 'published')
  const drafts = posts.filter(p => p.status === 'draft')

  const deleteMutation = useMutation({
    mutationFn: postsApi.delete,
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['my-posts'] }); toast.success('Post deleted') },
    onError: () => toast.error('Failed to delete post'),
  })

  return (
    <div className="max-w-3xl mx-auto px-4 py-10">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
          <p className="text-gray-500 text-sm mt-0.5">Welcome back, {user?.name}</p>
        </div>
        <Link to="/new" className="bg-gray-900 hover:bg-gray-700 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors">+ New Post</Link>
      </div>
      <div className="grid grid-cols-3 gap-4 mb-10">
        <div className="bg-gray-50 rounded-xl p-4 text-center">
          <div className="text-2xl font-semibold text-gray-900">{posts.length}</div>
          <div className="text-xs text-gray-500 mt-0.5">Total posts</div>
        </div>
        <div className="bg-gray-50 rounded-xl p-4 text-center">
          <div className="text-2xl font-semibold text-green-600">{published.length}</div>
          <div className="text-xs text-gray-500 mt-0.5">Published</div>
        </div>
        <div className="bg-gray-50 rounded-xl p-4 text-center">
          <div className="text-2xl font-semibold text-amber-600">{drafts.length}</div>
          <div className="text-xs text-gray-500 mt-0.5">Drafts</div>
        </div>
      </div>
      {isLoading ? (
        <div className="space-y-3">{[...Array(4)].map((_, i) => <div key={i} className="animate-pulse bg-gray-100 h-16 rounded-xl" />)}</div>
      ) : posts.length === 0 ? (
        <div className="text-center py-16 text-gray-400">No posts yet. <Link to="/new" className="text-gray-900 underline">Write your first post</Link></div>
      ) : (
        <div className="space-y-3">
          {posts.map(post => (
            <div key={post._id} className="flex items-center justify-between border border-gray-200 rounded-xl px-4 py-3 hover:border-gray-300 transition-colors">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2 mb-0.5">
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${post.status === 'published' ? 'bg-green-50 text-green-600' : 'bg-amber-50 text-amber-600'}`}>{post.status}</span>
                  <span className="text-xs text-gray-400">{format(new Date(post.createdAt), 'MMM d, yyyy')}</span>
                </div>
                <p className="text-sm font-medium text-gray-900 truncate">{post.title}</p>
              </div>
              <div className="flex items-center gap-2 ml-4 flex-shrink-0">
                {post.status === 'published' && <Link to={`/posts/${post.slug}`} className="text-xs text-gray-500 hover:text-gray-900 transition-colors">View</Link>}
                <Link to={`/edit/${post._id}`} className="text-xs text-gray-500 hover:text-gray-900 transition-colors">Edit</Link>
                <button onClick={() => { if (confirm('Delete this post?')) deleteMutation.mutate(post._id) }}
                  className="text-xs text-red-400 hover:text-red-600 transition-colors">Delete</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
EOF

# ─────────────────────────────────────────
# ROOT .gitignore
# ─────────────────────────────────────────
cat > .gitignore << 'EOF'
node_modules/
dist/
.env
*.log
.DS_Store
.vercel
EOF

echo -e "${YELLOW}[5/6] Installing backend dependencies...${NC}"
cd backend && npm install && cd ..

echo -e "${YELLOW}[6/6] Installing frontend dependencies...${NC}"
cd frontend && npm install && cd ..

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   ✅ Setup complete!                   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. ${YELLOW}cp backend/.env.example backend/.env${NC}"
echo -e "  2. Edit ${YELLOW}backend/.env${NC} and add your MongoDB URI"
echo -e "  3. Terminal 1: ${YELLOW}cd backend && npm run dev${NC}"
echo -e "  4. Terminal 2: ${YELLOW}cd frontend && npm run dev${NC}"
echo -e "  5. Open ${YELLOW}http://localhost:5173${NC}"
echo ""