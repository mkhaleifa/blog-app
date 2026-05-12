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
