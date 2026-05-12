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
