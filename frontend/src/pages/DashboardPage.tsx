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
