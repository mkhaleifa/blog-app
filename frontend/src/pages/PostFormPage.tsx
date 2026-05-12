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
