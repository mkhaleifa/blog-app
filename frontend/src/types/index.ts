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
