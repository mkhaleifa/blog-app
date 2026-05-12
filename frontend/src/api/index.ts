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
